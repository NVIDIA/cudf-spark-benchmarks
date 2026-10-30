WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        ps.ps_supplycost,
        ps.ps_availqty,
        p.p_retailprice,
        p.p_comment,
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.p_comment LIKE '%fragile%'
),
TotalPrice AS (
    SELECT 
        o.o_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_custkey
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        t.total_price
    FROM 
        customer c
    LEFT JOIN 
        TotalPrice t ON c.c_custkey = t.o_custkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.ps_supplycost,
    p.ps_availqty,
    c.c_name,
    c.c_address,
    COALESCE(c.total_price, 0) AS total_spent,
    CASE 
        WHEN c.total_price IS NULL THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_status
FROM 
    PartSupplierDetails p
JOIN 
    CustomerInfo c ON p.s_name = c.c_name
ORDER BY 
    total_spent DESC, p.p_retailprice ASC;