WITH ConcatenatedParts AS (
    SELECT 
        p.p_partkey, 
        CONCAT(p.p_name, ' | ', p.p_mfgr, ' | ', p.p_brand, ' | ', p.p_type) AS part_info
    FROM 
        part p
), 
SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_phone, 
        SUBSTRING(s.s_comment, 1, 30) AS short_comment
    FROM 
        supplier s
), 
OrdersWithDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        CONCAT(CAST(o.o_totalprice AS STRING), ' - ', o.o_orderstatus) AS order_total_status,
        c.c_name, 
        r.r_name 
    FROM 
        orders o 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey 
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey 
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey 
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
) 
SELECT 
    p.part_info, 
    s.s_name, 
    o.order_total_status, 
    o.o_orderdate, 
    COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM 
    ConcatenatedParts p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplierSummary s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    OrdersWithDetails o ON l.l_orderkey = o.o_orderkey 
GROUP BY 
    p.part_info, s.s_name, o.order_total_status, o.o_orderdate 
ORDER BY 
    total_orders DESC, o.o_orderdate DESC 
LIMIT 10;