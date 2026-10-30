WITH supplier_part_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        (ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(total_cost) AS total_value
    FROM 
        supplier_part_details s
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_value DESC
    LIMIT 10
),
customer_order_details AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value,
        c.c_mktsegment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, c.c_mktsegment
),
customer_summary AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    ts.s_name AS supplier_name,
    ts.total_value AS supplier_total_value,
    cs.c_mktsegment AS market_segment,
    cs.customer_count,
    cs.total_revenue,
    cs.avg_order_value
FROM 
    top_suppliers ts
JOIN 
    customer_summary cs ON cs.c_mktsegment IN ('BUILDING', 'FURNITURE', 'HOUSEHOLD')
ORDER BY 
    ts.total_value DESC, cs.total_revenue DESC;
