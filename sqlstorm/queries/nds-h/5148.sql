WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
Summary AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(DISTINCT hc.c_custkey) AS high_value_customers, 
        SUM(rs.total_cost) AS total_supplier_cost
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
    JOIN 
        HighValueCustomers hc ON rs.rank <= 10 
    GROUP BY 
        r.r_name
)
SELECT 
    region_name, 
    high_value_customers, 
    total_supplier_cost
FROM 
    Summary
ORDER BY 
    total_supplier_cost DESC, high_value_customers DESC;
