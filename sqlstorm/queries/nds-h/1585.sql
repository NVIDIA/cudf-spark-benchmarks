WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
TopParts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE rs.rank <= 5
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT 
    p.p_name, 
    p.p_brand, 
    p.p_retailprice, 
    COALESCE(t.total_cost, 0) AS total_supply_cost, 
    os.total_price AS order_total_price,
    CASE 
        WHEN os.total_price IS NULL THEN 'No Orders'
        ELSE 'With Orders'
    END AS order_status
FROM part p
LEFT JOIN TopParts t ON p.p_partkey = t.ps_partkey
LEFT JOIN OrderSummary os ON os.o_orderkey = (SELECT MAX(o_orderkey) FROM orders WHERE o_orderkey <= (SELECT MAX(o_orderkey) FROM orders))
WHERE p.p_size >= 20 AND p.p_retailprice BETWEEN 100.00 AND 500.00
ORDER BY p.p_retailprice DESC, total_supply_cost ASC;
