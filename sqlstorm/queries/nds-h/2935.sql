
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' 
    AND o.o_orderdate < '1998-01-01'
),
supply_info AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps 
    GROUP BY ps.ps_partkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
join_result AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        COALESCE(SUM(l.l_extendedprice), 0) AS total_lineitem_price
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey AND l.l_returnflag = 'N'
    GROUP BY c.c_name, o.o_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_orderstatus,
    r.o_totalprice,
    co.total_orders,
    co.total_spent,
    co.avg_order_value,
    si.total_available,
    si.total_supply_cost,
    jj.total_lineitem_price
FROM ranked_orders r
INNER JOIN customer_orders co ON r.o_orderkey = co.c_custkey
FULL OUTER JOIN supply_info si ON si.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0 ORDER BY ps.ps_supplycost LIMIT 1) 
LEFT JOIN join_result jj ON jj.o_orderkey = r.o_orderkey
WHERE r.rank_order <= 10
  AND r.o_orderstatus IN ('F', 'P')
ORDER BY r.o_totalprice DESC, co.total_spent DESC;
