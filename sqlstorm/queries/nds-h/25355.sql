WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        s.s_name AS supplier_name, 
        ps.ps_supplycost, 
        ps.ps_availqty,
        CONCAT(p.p_name, ' - ', s.s_name) AS detail_combination
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey,
        o.o_orderdate, 
        o.o_totalprice,
        CONCAT(c.c_name, ' - Order:', o.o_orderkey) AS customer_order_detail 
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
AggregatedData AS (
    SELECT 
        psd.p_partkey,
        psd.detail_combination,
        COUNT(DISTINCT co.o_orderkey) AS order_count,
        SUM(psd.ps_availqty) AS total_avail_qty,
        SUM(co.o_totalprice) AS total_order_value
    FROM 
        PartSupplierDetails psd
    LEFT JOIN 
        lineitem l ON psd.p_partkey = l.l_partkey
    LEFT JOIN 
        CustomerOrders co ON l.l_orderkey = co.o_orderkey
    GROUP BY 
        psd.p_partkey, psd.detail_combination
)
SELECT 
    ad.p_partkey,
    ad.detail_combination,
    ad.order_count,
    ad.total_avail_qty,
    ad.total_order_value
FROM 
    AggregatedData ad
WHERE 
    ad.total_order_value > 10000
ORDER BY 
    ad.total_order_value DESC, ad.order_count DESC;
