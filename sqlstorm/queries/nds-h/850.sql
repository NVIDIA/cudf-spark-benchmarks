
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS supplier_rank,
        p.p_type,
        p.p_retailprice,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey
),
RegionCustomerCount AS (
    SELECT 
        n.n_regionkey,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_regionkey
)

SELECT 
    r.r_name,
    rc.customer_count,
    SUM(rs.ps_availqty) AS total_available,
    AVG(co.total_spent) AS avg_spent_per_customer,
    COUNT(DISTINCT rs.s_suppkey) AS distinct_suppliers
FROM 
    region r
LEFT JOIN 
    RegionCustomerCount rc ON r.r_regionkey = rc.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON rs.p_type IN ('Small Box', 'Medium Box') 
LEFT JOIN 
    CustomerOrders co ON rc.customer_count = co.total_orders
WHERE 
    rs.supplier_rank <= 5
GROUP BY 
    r.r_name, rc.customer_count
ORDER BY 
    total_available DESC, avg_spent_per_customer DESC;
