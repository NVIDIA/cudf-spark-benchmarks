WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
supplier_details AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name, 
        sd.total_supply_cost,
        RANK() OVER (ORDER BY sd.total_supply_cost DESC) AS supplier_rank
    FROM 
        supplier_details sd
)
SELECT 
    ro.o_orderkey,
    ro.total_quantity,
    ro.total_revenue,
    ts.s_suppkey,
    ts.s_name,
    ts.total_supply_cost
FROM 
    ranked_orders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    top_suppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    ro.order_rank <= 5 AND ts.supplier_rank <= 10
ORDER BY 
    ro.total_revenue DESC, ts.total_supply_cost ASC;
