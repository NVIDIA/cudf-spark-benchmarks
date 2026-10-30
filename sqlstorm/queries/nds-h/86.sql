
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 3
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationalCustomerSpend AS (
    SELECT 
        n.n_name,
        SUM(cos.total_spent) AS total_spent_per_nation
    FROM 
        nation n
    JOIN 
        CustomerOrderSummary cos ON n.n_nationkey = cos.c_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    CASE 
        WHEN r.total_spent_per_nation IS NULL THEN 'N/A'
        ELSE CAST(r.total_spent_per_nation AS STRING)
    END AS total_spent_by_nation
FROM 
    part p 
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
LEFT JOIN 
    NationalCustomerSpend r ON ts.s_name = r.n_name
GROUP BY 
    p.p_partkey, p.p_name, r.total_spent_per_nation
HAVING 
    AVG(l.l_tax) IS NOT NULL
ORDER BY 
    order_count DESC, avg_discounted_price DESC;
