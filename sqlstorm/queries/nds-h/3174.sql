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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
FilteredLineItem AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o_orderstatus,
    li.total_revenue,
    COALESCE(ts.total_cost, 0) AS supplier_total_cost,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Completed' 
        ELSE 'Pending' 
    END AS order_status_description
FROM 
    RankedOrders o
LEFT JOIN 
    FilteredLineItem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON ts.ps_suppkey = li.l_orderkey
WHERE 
    o.order_rank <= 5
ORDER BY 
    o.o_orderdate DESC;