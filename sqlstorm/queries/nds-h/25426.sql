
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
StringComparison AS (
    SELECT 
        rp.p_name,
        LENGTH(rp.p_name) AS name_length,
        CONCAT('Supplier: ', sr.s_name, ', Region: ', sr.region_name) AS supplier_info,
        COALESCE(cu.order_count, 0) AS customer_order_count
    FROM 
        RankedParts rp
    JOIN 
        SupplierRegion sr ON sr.s_suppkey = rp.p_partkey
    LEFT JOIN 
        CustomerOrders cu ON cu.c_name LIKE CONCAT('%', SUBSTRING(rp.p_name, 1, 5), '%')
    WHERE 
        rp.rn = 1
)
SELECT 
    p_name,
    name_length,
    supplier_info,
    customer_order_count
FROM 
    StringComparison
ORDER BY 
    name_length DESC, customer_order_count DESC;
