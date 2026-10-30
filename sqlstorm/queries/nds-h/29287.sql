WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        p.p_comment,
        ps.ps_supplycost,
        CONCAT(p.p_name, ' ', p.p_mfgr, ' - Price: ', CAST(p.p_retailprice AS STRING), ' | Comment: ', p.p_comment) AS detailed_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        CONCAT(s.s_name, ' - Address: ', s.s_address, ' | Phone: ', s.s_phone) AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_name LIKE 'United%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        CONCAT(c.c_name, ' - Total Spent: ', CAST(SUM(o.o_totalprice) AS STRING), ' | Orders: ', COUNT(o.o_orderkey)) AS customer_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    pd.p_partkey,
    pd.detailed_info,
    sd.supplier_info,
    co.customer_summary
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON pd.p_partkey % 10 = sd.s_suppkey % 10
JOIN 
    CustomerOrders co ON pd.p_partkey % 10 = co.c_custkey % 10
WHERE 
    pd.ps_supplycost < 500
ORDER BY 
    pd.p_partkey, sd.s_suppkey, co.c_custkey;
