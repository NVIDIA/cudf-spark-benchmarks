
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS num_unique_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_nationkey,
        n.n_name,
        COALESCE(n.n_comment, 'No comment') AS nation_comment
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
),
ExceedingOrders AS (
    SELECT 
        o.o_custkey,
        SUM(o.total_price) AS total_customer_spending
    FROM OrderSummary o
    GROUP BY o.o_custkey
    HAVING SUM(o.total_price) > 10000
),
FinalResult AS (
    SELECT 
        cn.c_name,
        cn.n_name,
        rs.s_name,
        rs.total_supply_cost,
        eo.total_customer_spending
    FROM CustomerNation cn
    LEFT JOIN RankedSuppliers rs ON cn.n_nationkey = rs.s_nationkey
    LEFT JOIN ExceedingOrders eo ON cn.c_custkey = eo.o_custkey
    WHERE rs.rank = 1 OR rs.rank IS NULL
)
SELECT 
    fr.c_name,
    fr.n_name,
    fr.s_name,
    COALESCE(fr.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(fr.total_customer_spending, 0) AS total_customer_spending,
    CASE 
        WHEN fr.total_customer_spending > 5000 THEN 'High spender'
        WHEN fr.total_customer_spending BETWEEN 1000 AND 5000 THEN 'Medium spender'
        ELSE 'Low spender'
    END AS spending_category
FROM FinalResult fr
ORDER BY fr.n_name, fr.c_name;
