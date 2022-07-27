import 'package:test/test.dart';
import 'package:fuzzylogic/fuzzylogic.dart';

import 'dart:math';

class TestEmptyStringMembershipFunction extends MembershipFunction<String> {
  @override
  num getDegreeOfMembership(String s) =>
      max(1 - s.length / 10, 0); // 'True' for empty string.
}

void main() {
  group('FuzzySet', () {
    test('works with non-numeric crisp values', () {
      // TODO: figure out if we really need this
      // var emptyStringSet =
      //     new FuzzySet(new TestEmptyStringMembershipFunction(), "");
      // expect(emptyStringSet.getDegreeOfMembership(""), 1.0);
      // expect(emptyStringSet.getDegreeOfMembership("12345"), 0.5);
      // expect(emptyStringSet.getDegreeOfMembership("1234567890"), 0.0);
    }, skip: 'This would not be type-sound');
    test('creates default manifolds', () {
      var triangle = FuzzySet.Triangle(0, 10, 100);
      expect(triangle.getDegreeOfMembership(-10), 0.0);
      expect(triangle.getDegreeOfMembership(0), 0.0);
      expect(triangle.getDegreeOfMembership(5), 0.5);
      expect(triangle.getDegreeOfMembership(10), 1.0);
      expect(triangle.getDegreeOfMembership(100), 0.0);
      expect(triangle.getDegreeOfMembership(1000), 0.0);
      var trapezoid = FuzzySet.Trapezoid(10, 20, 30, 40);
      expect(trapezoid.getDegreeOfMembership(-10), 0.0);
      expect(trapezoid.getDegreeOfMembership(10), 0.0);
      expect(trapezoid.getDegreeOfMembership(20), 1.0);
      expect(trapezoid.getDegreeOfMembership(25), 1.0);
      expect(trapezoid.getDegreeOfMembership(30), 1.0);
      expect(trapezoid.getDegreeOfMembership(35), 0.5);
      expect(trapezoid.getDegreeOfMembership(40), 0.0);
      expect(trapezoid.getDegreeOfMembership(400), 0.0);
      var leftShoulder = FuzzySet.LeftShoulder(0, 10, 50);
      expect(leftShoulder.getDegreeOfMembership(-10), 1.0);
      expect(leftShoulder.getDegreeOfMembership(0), 1.0);
      expect(leftShoulder.getDegreeOfMembership(10), 1.0);
      expect(leftShoulder.getDegreeOfMembership(50), 0.0);
      expect(leftShoulder.getDegreeOfMembership(100), 0.0);
      var rightShoulder = FuzzySet.RightShoulder(0, 10, 50);
      expect(rightShoulder.getDegreeOfMembership(-10), 0.0);
      expect(rightShoulder.getDegreeOfMembership(0), 0.0);
      expect(rightShoulder.getDegreeOfMembership(10), 1.0);
      expect(rightShoulder.getDegreeOfMembership(50), 1.0);
      expect(rightShoulder.getDegreeOfMembership(100), 1.0);
    });
    // TODO: test saw-like manifolds
    test('finds the variable which it is assigned to', () {
      var roomTemperature = FuzzyVariable<int?>();
      var cold = FuzzySet.LeftShoulder(10, 15, 22);
      var comfortable = FuzzySet.Trapezoid(15, 20, 25, 30);
      var hot = FuzzySet.RightShoulder(25, 30, 35);
      roomTemperature.sets = [cold, comfortable, hot];
      roomTemperature.init();

      var currentRoomTemperature = roomTemperature.assign(0);

      cold.setDegreeOfTruth(1.0, [currentRoomTemperature]);
      expect(currentRoomTemperature.degreesOfTruth[cold], 1.0);
    });
  });

  group('FuzzyValue', () {
    test('computes degrees of truth and crisp value', () {
      var roomTemperature = FuzzyVariable<int>();
      var cold = FuzzySet.LeftShoulder(10, 15, 22);
      var comfortable = FuzzySet.Trapezoid(15, 20, 25, 30);
      var hot = FuzzySet.RightShoulder(25, 30, 35);
      roomTemperature.sets = [cold, comfortable, hot];
      roomTemperature.init();

      var currentRoomTemperature = roomTemperature.assign(0);

      expect(currentRoomTemperature.degreesOfTruth[cold], 1.0);
      expect(currentRoomTemperature.degreesOfTruth[hot], 0.0);
      expect(currentRoomTemperature.crispValue, lessThan(22));

      currentRoomTemperature = roomTemperature.assign(28);

      expect(currentRoomTemperature.degreesOfTruth[cold], 0.0);
      expect(
          currentRoomTemperature.degreesOfTruth[comfortable], greaterThan(0.0));
      expect(currentRoomTemperature.degreesOfTruth[comfortable], lessThan(1.0));
      expect(currentRoomTemperature.degreesOfTruth[hot], greaterThan(0.0));
      expect(currentRoomTemperature.degreesOfTruth[hot], lessThan(1.0));
      expect(currentRoomTemperature.degreesOfTruth[comfortable],
          lessThan(currentRoomTemperature.degreesOfTruth[hot]));
      expect(currentRoomTemperature.crispValue, greaterThan(22));
    });
  });

  // TODO: hedges
  // TODO: fuzzy rule
  // TODO: fuzzy ruleset

  group('The whole system', () {
    test(
        "correctly computes the 'Designing FLVs for Weapon Selection' example "
        "from Mat Buckland's book", () {
      // Set up variables.
      var distanceToTarget = Distance();
      var bazookaAmmo = Ammo();
      var bazookaDesirability = Desirability();

      // Add rules.
      var frb = FuzzyRuleBase();
      frb.addRules([
        (distanceToTarget.Far & bazookaAmmo.Loads) >>
            (bazookaDesirability.Desirable),
        (distanceToTarget.Far & bazookaAmmo.Okay) >>
            (bazookaDesirability.Undesirable),
        (distanceToTarget.Far & bazookaAmmo.Low) >>
            (bazookaDesirability.Undesirable),
        (distanceToTarget.Medium & bazookaAmmo.Loads) >>
            (bazookaDesirability.VeryDesirable),
        (distanceToTarget.Medium & bazookaAmmo.Okay) >>
            (bazookaDesirability.VeryDesirable),
        (distanceToTarget.Medium & bazookaAmmo.Low) >>
            (bazookaDesirability.Desirable),
        (distanceToTarget.Close) >> (bazookaDesirability.Undesirable)
      ]);

      // Create the placeholder for output.
      FuzzyValue<int?> bazookaOutput = bazookaDesirability.createOutputPlaceholder();

      // Use the fuzzy inference engine.
      frb.resolve(
          inputs: [distanceToTarget.assign(200), bazookaAmmo.assign(8)],
          outputs: [bazookaOutput]);

      expect(bazookaOutput.degreesOfTruth[bazookaDesirability.Desirable],
          closeTo(0.2, 0.01));
      expect(bazookaOutput.degreesOfTruth[bazookaDesirability.Undesirable],
          closeTo(0.33, 0.01));
      expect(bazookaOutput.degreesOfTruth[bazookaDesirability.VeryDesirable],
          closeTo(0.67, 0.01));
      expect(bazookaOutput.crispValue, greaterThan(60));
      expect(bazookaOutput.crispValue, lessThan(84));

      // Throws when trying to use the same output value twice
      expect(
          () => frb.resolve(
              inputs: [distanceToTarget.assign(5), bazookaAmmo.assign(8)],
              outputs: [bazookaOutput]),
          throwsA(const TypeMatcher<FuzzyLogicStateError>()));

      // Another try
      FuzzyValue<int?> bazookaOutput2 = bazookaDesirability.createOutputPlaceholder();
      frb.resolve(
          inputs: [distanceToTarget.assign(5), bazookaAmmo.assign(8)],
          outputs: [bazookaOutput2]);

      expect(bazookaOutput2.crispValue, lessThan(10));
    });
  });
}

class Distance extends FuzzyVariable<int> {
  var Close = FuzzySet.LeftShoulder(0, 25, 150);
  var Medium = FuzzySet.Triangle(25, 150, 300);
  var Far = FuzzySet.RightShoulder(150, 300, 400);

  Distance() {
    sets = [Close, Medium, Far];
    init();
  }
}

class Ammo extends FuzzyVariable<int> {
  var Low = FuzzySet.LeftShoulder(0, 0, 10);
  var Okay = FuzzySet.Triangle(0, 10, 30);
  var Loads = FuzzySet.RightShoulder(10, 30, 40);

  Ammo() {
    sets = [Low, Okay, Loads];
    init();
  }
}

class Desirability extends FuzzyVariable<int?> {
  var Undesirable = FuzzySet.LeftShoulder(0, 20, 50);
  var Desirable = FuzzySet.Triangle(20, 50, 70);
  var VeryDesirable = FuzzySet.RightShoulder(50, 70, 100);

  Desirability() {
    sets = [Undesirable, Desirable, VeryDesirable];
    init();
  }
}
