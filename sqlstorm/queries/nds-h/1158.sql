WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
),
ShippingDetails AS (
    SELECT
        l.l_orderkey,
        l.l_shipmode,
        COUNT(*) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_shipmode
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Open'
        WHEN r.o_orderstatus = 'F' THEN 'Finished'
        ELSE 'Unknown'
    END AS order_status,
    COALESCE(sd.total_supplycost, 0) AS supplier_total_supplycost,
    COALESCE(cust.total_spent, 0) AS customer_total_spent,
    sd.part_count,
    sh.item_count,
    sh.total_value
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierDetails sd ON sd.part_count > 5
LEFT JOIN 
    HighValueCustomers cust ON cust.c_custkey = r.o_orderkey
LEFT JOIN 
    ShippingDetails sh ON sh.l_orderkey = r.o_orderkey
WHERE 
    r.rank <= 10
    AND (r.o_orderstatus IS NOT NULL OR sd.total_supplycost IS NOT NULL)
ORDER BY 
    r.o_orderdate DESC;