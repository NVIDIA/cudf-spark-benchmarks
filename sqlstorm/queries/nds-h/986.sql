
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
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
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierInfo AS (
    SELECT 
        r.r_name AS region, 
        n.n_name AS nation, 
        s.s_name AS supplier_name,
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rnk <= 3
)
SELECT 
    hc.c_custkey, 
    hc.c_name, 
    COALESCE(si.region, 'Unknown') AS region, 
    COALESCE(si.nation, 'Unknown') AS nation,
    si.supplier_name,
    hc.total_spent
FROM 
    HighValueCustomers hc
LEFT JOIN 
    SupplierInfo si ON si.supplier_name LIKE CONCAT('%', hc.c_name, '%')
WHERE 
    hc.total_spent IS NOT NULL
ORDER BY 
    hc.total_spent DESC, 
    si.total_supplycost DESC
LIMIT 10;
