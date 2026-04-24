- this blog essentially uses z3 to make propositions for lean
- so it cannot be useful in the way we thought to create a lean replacement because that would be essentially building the z3py ast
- Good news is I am trying to use lean-smt to replace it : https://github.com/ufmg-smite/lean-smt
- Lets try to do some basic cvc5 : https://cvc5.github.io/tutorials/beginners/overview.html
- Trying to solve a simple thing

### --- Problem ---
```python
from cvc5.pythonic import *
a, b = Ints('a b')
solve(a + 10 == 2 * b, b + 22 == 2 * a)
```

### --- Solution ---
```python
[a = 18, b = 14]
```



## lean-smt


```scheme
(set-logic QF_LIA)
(set-option :produce-models true)

(declare-const a Int)
(declare-const b Int)

(assert (= (+ a 10) (* 2 b)))
(assert (= (+ b 22) (* 2 a)))

(check-sat)
(get-model)
```

if I have to convert that as a DSL in lean I will do the following

- example to follow : https://github.com/ufmg-smite/lean-smt/blob/7d1d8239e78daa5197f9a71948776c4627049f5f/Test/Solver/Interactive.lean
- 