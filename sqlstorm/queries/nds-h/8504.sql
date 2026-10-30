WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_nationkey
    FROM 
        ranked_orders ro
    WHERE 
        ro.order_rank <= 5
),
supplier_stats AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey
),
order_details AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_returnflag,
        l.l_linestatus,
        l.l_shipdate
    FROM 
        lineitem l
    JOIN 
        top_orders o ON l.l_orderkey = o.o_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.c_name,
    s.s_name,
    ss.total_avail_qty,
    ss.avg_supply_cost,
    SUM(od.l_extendedprice) AS total_extended_price,
    SUM(od.l_discount) AS total_discount
FROM 
    order_details od
JOIN 
    top_orders o ON od.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON od.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    supplier_stats ss ON ps.ps_suppkey = ss.ps_suppkey
GROUP BY 
    o.o_orderkey, o.o_orderdate, o.c_name, s.s_name, ss.total_avail_qty, ss.avg_supply_cost
ORDER BY 
    o.o_orderdate DESC, total_extended_price DESC;
