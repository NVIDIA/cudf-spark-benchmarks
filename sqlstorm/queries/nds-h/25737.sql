
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        SUBSTRING(s.s_comment FROM 1 FOR 50) AS short_comment
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal > 3000
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_retailprice,
        p.p_comment
    FROM 
        part p 
    WHERE 
        LENGTH(p.p_name) > 20 AND
        p.p_size BETWEEN 10 AND 30
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        l.l_suppkey, 
        l.l_quantity, 
        CONCAT('OrderKey: ', l.l_orderkey, ', Quantity: ', l.l_quantity) AS order_info 
    FROM 
        lineitem l 
    WHERE 
        l.l_returnflag = 'R'
),
FinalOutput AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name, 
        pd.p_partkey, 
        pd.p_name, 
        pd.p_brand, 
        ld.order_info
    FROM 
        SupplierDetails sd
    JOIN 
        partsupp ps ON sd.s_suppkey = ps.ps_suppkey
    JOIN 
        PartDetails pd ON ps.ps_partkey = pd.p_partkey
    JOIN 
        LineItemDetails ld ON ps.ps_partkey = ld.l_partkey
    WHERE 
        sd.s_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name LIKE '%land%'
        )
)
SELECT 
    f.s_name, 
    f.p_name, 
    f.order_info 
FROM 
    FinalOutput f 
ORDER BY 
    f.s_name, 
    f.p_name;
