use "rules";

export class Enemy
{
  init(name, level)
  {
    this.name = name;
    this.level = level;
    this.health = 40 + level * 10;
    this.power = 8 + level * 3;
    this.armor = level * 2;
  }

  isAlive()
  {
    return this.health > 0;
  }

  attack(target)
  {
    let amount = rules.damage(this.power, target.armor);
    target.health = target.health - amount;
    if (target.health < 0)
      target.health = 0;
    return amount;
  }
}
