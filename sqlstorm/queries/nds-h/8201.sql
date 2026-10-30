
WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
), sales_summary AS (
    SELECT 
        c.c_nationkey, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_nationkey
), combined_data AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        n.n_nationkey, 
        n.n_name, 
        ss.total_orders, 
        ss.total_sales, 
        rp.total_available_qty, 
        rp.avg_supply_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        sales_summary ss ON n.n_nationkey = ss.c_nationkey
    LEFT JOIN 
        ranked_parts rp ON n.n_nationkey IN (
            SELECT s.s_nationkey 
            FROM supplier s 
            JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
            WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p)
        )
)
SELECT 
    r_name, 
    n_name, 
    total_orders, 
    total_sales, 
    total_available_qty, 
    avg_supply_cost
FROM 
    combined_data
WHERE 
    total_orders IS NOT NULL 
ORDER BY 
    total_sales DESC 
LIMIT 10;
