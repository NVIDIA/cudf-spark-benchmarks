WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.nation
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS distinct_customers,
        COUNT(l.l_orderkey) AS total_lineitems,
        t.s_name AS supplier_name,
        t.nation AS supplier_nation
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers t ON ps.ps_suppkey = t.s_suppkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, t.s_name, t.nation
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    od.total_revenue,
    od.distinct_customers,
    od.total_lineitems,
    od.supplier_name,
    od.supplier_nation
FROM 
    OrderDetails od
WHERE 
    od.total_revenue > 10000
ORDER BY 
    od.total_revenue DESC, 
    od.o_orderdate ASC
LIMIT 100;
