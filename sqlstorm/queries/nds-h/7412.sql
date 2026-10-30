WITH RegionCustomerStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        SUM(c.c_acctbal) AS total_account_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_value DESC
    LIMIT 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_tax) AS total_tax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    rcs.region_name,
    rcs.total_customers,
    rcs.total_account_balance,
    ts.s_name AS top_supplier_name,
    ts.total_value AS top_supplier_value,
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    os.total_tax
FROM 
    RegionCustomerStats rcs
CROSS JOIN 
    TopSuppliers ts
JOIN 
    OrderStats os ON os.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
WHERE 
    rcs.total_customers > 100
ORDER BY 
    rcs.total_account_balance DESC, ts.total_value DESC, os.total_revenue DESC;