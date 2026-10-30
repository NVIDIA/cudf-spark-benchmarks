
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
), high_value_orders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        n.n_name,
        CASE
            WHEN r.o_totalprice > 10000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS order_value_category
    FROM 
        ranked_orders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 10
), part_supplier_details AS (
    SELECT 
        ps.ps_partkey,
        p.p_brand,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_available_qty,
        MIN(ps.ps_supplycost) AS lowest_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_brand, p.p_mfgr
), final_summary AS (
    SELECT 
        h.o_orderkey,
        h.o_orderdate,
        h.order_value_category,
        COALESCE(p.total_available_qty, 0) AS total_available_qty,
        COALESCE(p.lowest_supply_cost, 0) AS lowest_supply_cost,
        CASE 
            WHEN h.order_value_category = 'High Value' THEN h.o_totalprice * 0.1 
            ELSE 0 
        END AS discount_value
    FROM 
        high_value_orders h
    LEFT JOIN 
        part_supplier_details p ON h.o_orderkey = p.ps_partkey
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.order_value_category,
    f.total_available_qty,
    f.lowest_supply_cost,
    f.discount_value,
    ROW_NUMBER() OVER (PARTITION BY f.order_value_category ORDER BY f.o_orderdate DESC) AS ranking
FROM 
    final_summary f
ORDER BY 
    f.order_value_category, f.o_orderdate DESC;
