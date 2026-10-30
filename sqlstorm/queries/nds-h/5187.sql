WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
TopSuppliers AS (
    SELECT 
        rs.region,
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        ts.s_suppkey,
        ts.s_name
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    COUNT(DISTINCT od.l_partkey) AS total_parts_supplied,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue,
    MAX(od.l_quantity) AS max_quantity,
    AVG(od.l_extendedprice) AS average_price_per_part
FROM 
    OrderDetails od
GROUP BY 
    od.o_orderkey, od.o_orderdate
ORDER BY 
    total_revenue DESC
LIMIT 10;
