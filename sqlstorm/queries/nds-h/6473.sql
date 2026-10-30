WITH  order_parts AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
supplier_info AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
top_products AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        op.total_revenue,
        si.total_supply_cost,
        (op.total_revenue - si.total_supply_cost) AS profit
    FROM 
        part p
    JOIN 
        order_parts op ON p.p_partkey = op.o_orderkey
    JOIN 
        supplier_info si ON p.p_partkey = si.ps_partkey
    ORDER BY 
        profit DESC
    LIMIT 10
)
SELECT 
    p.p_name,
    p.p_retailprice,
    tp.total_revenue,
    tp.total_supply_cost,
    tp.profit
FROM 
    top_products tp
JOIN 
    part p ON tp.p_partkey = p.p_partkey;