
WITH  sales_hierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
), 
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_availqty DESC) AS availability_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
), 
order_details AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)

SELECT 
    c.c_name,
    SUM(od.total_revenue) AS total_revenue,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    AVG(rh.order_rank) AS average_order_rank,
    STRING_AGG(DISTINCT CONCAT(ps.p_name, ' (Supplied by: ', ps.s_name, ')'), ', ') AS supplier_parts
FROM 
    sales_hierarchy rh
LEFT JOIN 
    order_details od ON rh.o_orderkey = od.o_orderkey
LEFT JOIN 
    part_supplier ps ON od.o_orderkey = ps.p_partkey
LEFT JOIN 
    customer c ON rh.c_custkey = c.c_custkey
WHERE 
    rh.o_orderdate >= DATE '1996-01-01'
GROUP BY 
    c.c_custkey, c.c_name
HAVING 
    SUM(od.total_revenue) > 50000
ORDER BY 
    total_revenue DESC
LIMIT 10;
