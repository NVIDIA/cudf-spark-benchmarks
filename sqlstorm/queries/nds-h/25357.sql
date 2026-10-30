WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type, ', Size: ', p.p_size) AS full_description,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        CONCAT(s.s_name, ' located at ', s.s_address, ' can be contacted at ', s.s_phone) AS supplier_info
    FROM 
        supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        COUNT(l.l_orderkey) AS total_lines,
        CONCAT('Order No: ', o.o_orderkey, ' on ', o.o_orderdate, ' with status ', o.o_orderstatus) AS order_summary
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority
)
SELECT 
    pd.full_description,
    sd.supplier_info,
    od.order_summary,
    od.o_totalprice
FROM 
    PartDetails pd
JOIN 
    SupplierDetails sd ON pd.p_partkey = sd.s_suppkey
JOIN 
    OrderDetails od ON od.total_lines > 10
WHERE 
    pd.total_available > 0
ORDER BY 
    od.o_totalprice DESC;
