WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.nation,
        r.s_suppkey,
        r.s_name,
        r.s_acctbal
    FROM 
        RankedSuppliers r
    WHERE 
        r.rn <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
FinalResult AS (
    SELECT 
        ts.nation,
        os.o_orderdate,
        SUM(os.total_revenue) AS total_revenue_by_nation
    FROM 
        TopSuppliers ts
    JOIN 
        orders o ON ts.s_suppkey = o.o_custkey
    JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        ts.nation, os.o_orderdate
)
SELECT 
    nation,
    o_orderdate,
    total_revenue_by_nation
FROM 
    FinalResult
ORDER BY 
    nation, o_orderdate DESC;
