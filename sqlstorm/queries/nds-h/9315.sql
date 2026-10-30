
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT fs.nation_name, fp.p_name, SUM(fp.ps_supplycost) AS total_supplycost, 
       MAX(cs.total_orders) AS max_orders, SUM(cs.total_spent) AS total_revenue
FROM RankedSuppliers fs
JOIN FilteredParts fp ON fs.s_suppkey = fp.p_partkey
JOIN CustomerOrderStats cs ON fs.s_suppkey = cs.c_custkey
WHERE fs.rank <= 5
GROUP BY fs.nation_name, fp.p_name
ORDER BY total_supplycost DESC, max_orders ASC;
