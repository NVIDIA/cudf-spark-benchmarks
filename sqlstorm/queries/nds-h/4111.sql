WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
supplier_parts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS lowest_cost_supplier
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
),
order_details AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        SUM(lo.l_quantity) AS total_quantity
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate >= '1997-01-01' AND lo.l_shipdate < '1997-12-31'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    od.total_revenue,
    od.total_quantity,
    COALESCE(sp.p_name, 'No parts') AS part_name,
    CASE 
        WHEN sp.lowest_cost_supplier = 1 THEN 'Cheapest Supplier'
        ELSE 'Other Supplier'
    END AS supplier_status
FROM 
    ranked_orders ro
LEFT JOIN 
    order_details od ON ro.o_orderkey = od.l_orderkey
LEFT JOIN 
    supplier_parts sp ON sp.ps_partkey = (
        SELECT 
            ps.ps_partkey
        FROM 
            supplier_parts ps
        WHERE 
            ps.lowest_cost_supplier = 1
        LIMIT 1
    )
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;