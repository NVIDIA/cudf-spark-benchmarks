WITH RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
TopCostlyParts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY total_cost DESC) AS rank
    FROM
        RankedParts
    WHERE
        p_brand LIKE 'Brand#%'
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        cv.total_spent
    FROM
        CustomerOrders cv
    JOIN
        customer c ON cv.c_custkey = c.c_custkey
    WHERE
        cv.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
)
SELECT
    hvc.c_name,
    hvc.c_address,
    hvc.total_spent,
    tcp.p_name,
    tcp.total_cost,
    sd.s_name AS supplier_name,
    sd.total_supply_value
FROM
    HighValueCustomers hvc
JOIN
    TopCostlyParts tcp ON hvc.total_spent > (SELECT AVG(total_cost) FROM TopCostlyParts)
JOIN
    SupplierDetails sd ON sd.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierDetails)
WHERE
    tcp.rank <= 5
ORDER BY
    hvc.total_spent DESC, tcp.total_cost DESC, sd.total_supply_value DESC;
