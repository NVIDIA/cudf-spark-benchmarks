WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rn
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
        rs.nation_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        c.c_name AS customer_name, 
        l.l_partkey, 
        p.p_name, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount, 
        l.l_tax, 
        ts.s_name AS supplier_name, 
        ts.s_acctbal
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
)
SELECT 
    od.customer_name,
    COUNT(DISTINCT od.o_orderkey) AS total_orders,
    SUM(od.l_extendedprice) AS total_revenue,
    AVG(od.s_acctbal) AS avg_supplier_balance
FROM 
    OrderDetails od
GROUP BY 
    od.customer_name
ORDER BY 
    total_revenue DESC
LIMIT 10;