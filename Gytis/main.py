import machine, random, json, time

chars = [el for el in "abcdefghijklmnopqrstuvwxyz"]

string = ""

for el in range(3):
    string += random.choice(chars)

with open("morse.json", "r+") as f:
    data = json.load(f)

encoded = "_".join([data[character.upper()] for character in string])

symbolTimings = {
    ".": 0.25,
    "-": 1,
    " ": 7
}

time.sleep(1)

for symbol in encoded:
    machine.Pin("LED").off()
    time.sleep(0.1)
    if symbol != "_":
        machine.Pin("LED").on()
        time.sleep(symbolTimings[symbol])
        continue
    #next letter
    time.sleep(3)
machine.Pin("LED").off()

input("want word?")

print(string)
print(" ".join(encoded.split("_")))