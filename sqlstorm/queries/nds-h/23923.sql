
WITH  price_over_time AS (
    SELECT 
        l_orderkey, 
        l_partkey, 
        l_suppkey, 
        SUM(l_extendedprice * (1 - l_discount)) OVER (PARTITION BY l_orderkey ORDER BY l_shipdate) AS cumulative_price,
        l_shipdate
    FROM 
        lineitem
    WHERE 
        l_shipdate BETWEEN '1995-01-01' AND '1996-12-31'
),
high_value_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
supplier_ranking AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supply_rank
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty IS NOT NULL
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    p.p_name, 
    r.r_name AS region_name,
    AVG(c.c_acctbal) AS average_account_balance,
    COALESCE(DENSE_RANK() OVER (PARTITION BY r.r_regionkey ORDER BY AVG(c.c_acctbal)), 0) AS region_customer_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    high_value_orders h ON h.o_orderkey = s.s_suppkey 
JOIN 
    customer c ON c.c_custkey = h.o_orderkey
WHERE 
    r.r_name IS NOT NULL 
    AND (h.total_order_value > (SELECT AVG(total_order_value) FROM high_value_orders) 
    OR s.s_suppkey IN (SELECT ps_suppkey FROM supplier_ranking WHERE supply_rank <= 10))
GROUP BY 
    p.p_name, r.r_name, r.r_regionkey
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 0
ORDER BY 
    average_account_balance DESC, p.p_name
LIMIT 100 OFFSET 10;
