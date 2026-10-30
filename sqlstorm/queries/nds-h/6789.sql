
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_sales DESC
    LIMIT 5
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
    ORDER BY 
        total_cost DESC
    LIMIT 5
)
SELECT 
    tn.n_name AS nation,
    tn.total_sales AS nation_total_sales,
    ts.s_name AS top_supplier,
    ts.total_cost AS supplier_total_cost,
    ro.o_orderkey,
    ro.o_totalprice,
    ro.o_orderdate
FROM 
    RankedOrders ro
JOIN 
    TopNations tn ON ro.o_orderdate >= '1997-01-01' AND ro.o_orderdate < '1997-12-31'
JOIN 
    TopSuppliers ts ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31')
WHERE 
    ro.order_rank <= 10
ORDER BY 
    tn.total_sales DESC, ts.total_cost DESC;
