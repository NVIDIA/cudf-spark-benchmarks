WITH SupplierPartInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount, 
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), 
Result AS (
    SELECT 
        spi.s_name, 
        spi.p_name, 
        SUM(od.l_quantity) AS total_quantity,
        SUM(od.l_extendedprice * (1 - od.l_discount)) AS revenue,
        COUNT(DISTINCT od.o_orderkey) AS total_orders
    FROM 
        SupplierPartInfo spi
    JOIN 
        OrderDetails od ON spi.p_partkey = od.l_partkey
    WHERE 
        od.o_orderdate >= DATE '1997-01-01' AND od.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        spi.s_name, 
        spi.p_name
    ORDER BY 
        revenue DESC, 
        total_quantity DESC
)
SELECT 
    r.s_name, 
    r.p_name, 
    r.total_quantity, 
    r.revenue, 
    r.total_orders
FROM 
    Result r
WHERE 
    r.total_orders > 5
LIMIT 10;