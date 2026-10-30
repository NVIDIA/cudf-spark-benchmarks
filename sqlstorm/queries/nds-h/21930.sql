WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_availability,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL 
        AND COUNT(o.o_orderkey) > 0
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(c.c_custkey) AS customer_count,
        SUM(coalesce(c.c_acctbal, 0.00)) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
SupplierOrderStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(l.l_orderkey) AS lines_supplied,
        AVG(l.l_discount) AS average_discount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    ns.n_name,
    ns.customer_count,
    ns.total_account_balance,
    rs.s_name,
    rs.total_availability,
    so.lines_supplied,
    so.average_discount
FROM 
    NationSummary ns
JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey
JOIN 
    SupplierOrderStats so ON rs.s_suppkey = so.s_suppkey
WHERE 
    (ns.total_account_balance > 5000 OR ns.customer_count > 10)
    AND rs.rank <= 5
ORDER BY 
    ns.customer_count DESC, rs.total_availability ASC
LIMIT 
    10;
