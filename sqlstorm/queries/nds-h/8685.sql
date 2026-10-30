WITH OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost,
        (l.l_extendedprice * (1 - l.l_discount)) AS discounted_price
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
Summary AS (
    SELECT 
        od.o_orderkey,
        COUNT(*) AS total_items,
        SUM(od.discounted_price) AS total_discounted_price,
        SUM(od.l_quantity) AS total_quantity,
        AVG(od.ps_supplycost) AS avg_supply_cost
    FROM 
        OrderDetails od
    GROUP BY 
        od.o_orderkey
)
SELECT 
    s.o_orderkey,
    s.total_items,
    s.total_discounted_price,
    s.total_quantity,
    s.avg_supply_cost,
    r.r_name AS region_name
FROM 
    Summary s
JOIN 
    customer c ON s.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.total_discounted_price > 10000
ORDER BY 
    s.total_discounted_price DESC;