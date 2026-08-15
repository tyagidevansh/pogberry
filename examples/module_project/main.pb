use "player" as player;
use "enemy" as enemy;
use "rules" as rules;

let hero = player.Player("Mira");
let slime = enemy.Enemy("Cave slime", 2);

print("Battle begins");
print(hero.name);
print(slime.name);

while (hero.isAlive() and slime.isAlive())
{
  print(hero.attack(slime));
  if (slime.isAlive())
    print(slime.attack(hero));

  if (hero.health <= 60 and len(hero.inventory) > 0)
    print(hero.heal());
}

if (hero.isAlive())
{
  hero.gainExperience(slime.level);
  print("Victory");
  print(hero.health);
  print(hero.experience);
  print(rules.reward(slime.level));
}
else
{
  print("Defeat");
}
