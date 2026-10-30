WITH order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), supplier_summary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
), part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_sold_quantity,
        AVG(l.l_extendedprice) AS avg_price_per_unit
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    os.unique_customers,
    ss.total_supply_cost,
    ss.unique_suppliers,
    ps.p_partkey,
    ps.p_name,
    ps.total_sold_quantity,
    ps.avg_price_per_unit
FROM 
    order_summary os
JOIN 
    supplier_summary ss ON os.total_quantity > 1000
JOIN 
    part_summary ps ON ps.total_sold_quantity > 5000
ORDER BY 
    os.total_revenue DESC, ss.total_supply_cost ASC;