WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
TopSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        sd.acct_rank
    FROM 
        SupplierDetails sd
    WHERE 
        sd.acct_rank <= 3
)
SELECT 
    os.o_orderkey,
    os.total_revenue,
    ts.s_name,
    ts.nation_name
FROM 
    OrderSummary os
LEFT JOIN 
    lineitem l ON os.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    os.total_revenue > 1000
ORDER BY 
    os.total_revenue DESC, ts.nation_name, ts.s_name;
