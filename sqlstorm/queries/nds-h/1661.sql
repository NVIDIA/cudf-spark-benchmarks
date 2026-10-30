WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.total_discounted_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSpend cs
)
SELECT 
    r.r_name,
    SUM(ss.total_supply_cost) AS total_supplier_cost,
    AVG(tc.total_spent) AS average_customer_spent,
    COUNT(DISTINCT tc.c_custkey) AS customer_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerSpend cs ON n.n_nationkey = cs.c_custkey
LEFT JOIN 
    TopCustomers tc ON cs.c_custkey = tc.c_custkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT ss.s_suppkey) > 5 AND AVG(tc.total_spent) IS NOT NULL
ORDER BY 
    total_supplier_cost DESC;