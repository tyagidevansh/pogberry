use "player" as player;
use "enemy" as enemy;
use "rules" as rules;

fun showStatus(hero, opponent)
{
  print("");
  print("Your health: " + str(hero.health));
  print(opponent.name + " health: " + str(opponent.health));
  print("Potions: " + str(len(hero.inventory)));
}

fun showActions()
{
  print("");
  print("Choose an action:");
  print("1 - Attack");
  print("2 - Use a potion");
  print("3 - Inspect the battle");
  print("4 - Quit");
}

let name = strInput("Hero name: ");
if (name == nil or name == "")
  name = "Mira";

let hero = player.Player(name);
let slime = enemy.Enemy("Cave slime", 2);
let running = true;

print("");
print("Welcome, " + hero.name + ".");
print("A " + slime.name + " blocks the road.");

while (running and hero.isAlive() and slime.isAlive())
{
  showStatus(hero, slime);
  showActions();
  let action = strInput("Action: ");
  let enemyTurn = false;

  if (action == nil)
  {
    print("");
    print("Input closed. Ending the adventure.");
    running = false;
  }
  else if (action == "1" or action == "attack")
  {
    let dealt = hero.attack(slime);
    print("");
    print("You deal " + str(dealt) + " damage.");
    enemyTurn = true;
  }
  else if (action == "2" or action == "heal")
  {
    let healed = hero.heal();
    print("");
    if (healed > 0)
      print("You recover " + str(healed) + " health.");
    else
      print("You have no potions left.");
    enemyTurn = true;
  }
  else if (action == "3" or action == "inspect")
  {
    print("");
    print("Your power: " + str(hero.power));
    print("Your armor: " + str(hero.armor));
    print("Enemy power: " + str(slime.power));
    print("Enemy armor: " + str(slime.armor));
  }
  else if (action == "4" or action == "quit")
  {
    print("");
    print("You leave the battle.");
    running = false;
  }
  else
  {
    print("");
    print("Please enter 1, 2, 3, or 4.");
  }

  if (enemyTurn and slime.isAlive())
  {
    let received = slime.attack(hero);
    print("The " + slime.name + " deals " + str(received) + " damage.");
  }
}

if (hero.isAlive())
{
  if (!slime.isAlive())
  {
    hero.gainExperience(slime.level);
    print("");
    print("Victory!");
    print("Health remaining: " + str(hero.health));
    print("Experience earned: " + str(rules.reward(slime.level)));
    print("Total experience: " + str(hero.experience));
  }
}
else
{
  print("");
  print("Defeat. The road remains blocked.");
}
