
WITH ProcessedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        UPPER(p.p_type) AS upper_type,
        SUBSTRING(p.p_comment, 1, 5) AS short_comment -- Using standard SQL for substring
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        CONCAT(s.s_address, ', ', r.r_name) AS full_address
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    pp.p_partkey,
    pp.p_name,
    pp.upper_type,
    pp.short_comment,
    si.s_name,
    si.full_address,
    co.c_name,
    co.order_count,
    co.total_spent
FROM 
    ProcessedParts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    CustomerOrders co ON o.o_custkey = co.c_custkey
WHERE 
    co.total_spent > 1000
ORDER BY 
    pp.p_name, co.order_count DESC;
