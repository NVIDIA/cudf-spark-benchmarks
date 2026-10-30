WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sd.total_available,
        sd.total_cost
    FROM 
        SupplierDetails sd
    JOIN 
        supplier s ON sd.s_suppkey = s.s_suppkey
    WHERE 
        sd.total_cost > 10000
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS linecount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    hs.s_name AS supplier_name,
    hs.total_available,
    hs.total_cost,
    COALESCE(rd.total_line_revenue, 0) AS order_revenue,
    (SELECT COUNT(*) FROM lineitem WHERE l_orderkey = r.o_orderkey AND l_returnflag = 'R') AS returned_items
FROM 
    RankedOrders r
LEFT JOIN 
    RecentOrders rd ON r.o_orderkey = rd.o_orderkey
LEFT JOIN 
    HighValueSuppliers hs ON hs.total_available >= 50
WHERE 
    r.rnk <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;