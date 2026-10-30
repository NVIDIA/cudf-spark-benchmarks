WITH  supply_value AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
customer_region AS (
    SELECT 
        c.c_custkey,
        n.n_nationkey,
        r.r_regionkey
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
supply_data AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(sv.total_supply_cost, 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        supply_value sv ON p.p_partkey = sv.ps_partkey
)
SELECT 
    cr.r_regionkey,
    SUM(so.total_price) AS aggregate_price,
    COUNT(DISTINCT so.o_orderkey) AS order_count,
    AVG(sd.total_supply_cost) AS average_supply_cost,
    MAX(sd.total_supply_cost) AS max_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT so.o_orderkey) > 0 THEN 
            SUM(so.total_price) / COUNT(DISTINCT so.o_orderkey) 
        ELSE 
            NULL 
    END AS avg_price_per_order
FROM 
    customer_region cr
LEFT JOIN 
    ranked_orders so ON cr.c_custkey = so.o_custkey
LEFT JOIN 
    supply_data sd ON cr.r_regionkey = sd.p_partkey
WHERE 
    cr.r_regionkey IS NOT NULL
GROUP BY 
    cr.r_regionkey
ORDER BY 
    cr.r_regionkey ASC;
