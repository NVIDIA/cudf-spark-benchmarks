WITH RankedProducts AS (
    SELECT 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        SUM(l.l_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_quantity) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_name, p.p_brand, p.p_type
),
TopProducts AS (
    SELECT 
        rp.p_name, 
        rp.p_brand, 
        rp.p_type, 
        rp.total_quantity
    FROM 
        RankedProducts rp
    WHERE 
        rp.rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        COUNT(ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_nationkey, s.s_acctbal
)

SELECT 
    tp.p_name AS product_name,
    tp.p_brand AS brand,
    tp.p_type AS type,
    sd.s_name AS supplier_name,
    sd.s_acctbal AS supplier_account_balance,
    sd.supply_count AS number_of_parts_supplied
FROM 
    TopProducts tp
JOIN 
    SupplierDetails sd ON tp.p_brand = sd.s_name
WHERE 
    sd.s_acctbal > 50000
ORDER BY 
    tp.p_type, tp.total_quantity DESC, sd.s_name;
