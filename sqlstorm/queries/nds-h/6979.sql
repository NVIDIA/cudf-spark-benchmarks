WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
), 
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    WHERE 
        ro.order_rank <= 10
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.o_orderstatus
), 
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        HighValueOrders ho ON l.l_orderkey = ho.o_orderkey
    JOIN 
        orders o ON ho.o_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_sales,
    ts.order_count
FROM 
    TopSuppliers ts
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    ts.total_sales DESC;