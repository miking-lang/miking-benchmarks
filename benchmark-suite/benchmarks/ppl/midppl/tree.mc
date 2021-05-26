
-- Tree type definition
type Tree
con Node : {left : Tree, right : Tree, age : Float } -> Tree
con Leaf : {age : Float} -> Tree


-- Project the age from a tree
let getAge = lam n. match n with Node r then r.age else
                 match n with Leaf r then r.age else
                 never

-- Count the number of leaves in a tree
recursive
let countLeaves = lam tree.
  match tree with Node r then
    addf (countLeaves r.left) (countLeaves r.right)
  else 1.
end
