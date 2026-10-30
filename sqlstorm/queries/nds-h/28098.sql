WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_acctbal,
        CONCAT('Supplier Name: ', s.s_name, ', Address: ', s.s_address, ', Balance: ', CAST(s.s_acctbal AS STRING)) AS Supplier_Info
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IN (1, 2, 3) THEN 'Small'
            WHEN p.p_size BETWEEN 4 AND 10 THEN 'Medium'
            ELSE 'Large' 
        END AS Size_Category,
        CONCAT('Part Name: ', p.p_name, ', Manufacturer: ', p.p_mfgr, ', Retail Price: ', CAST(p.p_retailprice AS STRING)) AS Part_Info
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 50.00 AND 500.00
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        CONCAT('Customer: ', c.c_name, ', Order Date: ', CAST(o.o_orderdate AS STRING), ', Total Price: ', CAST(o.o_totalprice AS STRING)) AS Order_Info
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    sd.Supplier_Info,
    pd.Part_Info,
    od.Order_Info
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    OrderDetails od ON li.l_orderkey = od.o_orderkey
WHERE 
    sd.s_name LIKE 'Supplier%' AND 
    pd.Size_Category = 'Medium'
ORDER BY 
    od.o_totalprice DESC
LIMIT 100;
