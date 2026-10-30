
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
), 
PartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        SUM(pd.total_availqty * pd.avg_supplycost) AS supplier_value
    FROM 
        supplier s
    JOIN 
        PartDetails pd ON s.s_suppkey = pd.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey
    HAVING 
        SUM(pd.total_availqty * pd.avg_supplycost) > 10000
),
NationOrderSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    nos.order_count,
    nos.total_revenue,
    ts.supplier_value
FROM 
    NationOrderSummary nos
JOIN 
    nation n ON nos.n_name = n.n_name
JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
ORDER BY 
    nos.total_revenue DESC, nos.order_count DESC;
